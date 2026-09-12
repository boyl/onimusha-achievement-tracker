"""从干净的 Git HEAD 构建确定性 Nexus 安装包；仅依赖 Python 标准库。"""
import argparse
import hashlib
import io
import json
import pathlib
import subprocess
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]

def git(*args):
    return subprocess.run(['git', '-C', str(ROOT), *args], check=True, stdout=subprocess.PIPE).stdout

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=pathlib.Path, default=ROOT/'dist')
    args = parser.parse_args()
    if git('status', '--porcelain').strip():
        raise SystemExit('工作树必须干净；请先提交要发布的文件。')
    head = git('rev-parse', 'HEAD').decode().strip()
    with zipfile.ZipFile(io.BytesIO(git('archive', '--format=zip', head))) as source:
        manifest = json.loads(source.read('文件校验.json'))
        expected = {'payload/'+e['path'] for e in manifest['files']}
        actual = {n for n in source.namelist() if n.startswith('payload/') and not n.endswith('/')}
        if expected != actual:
            raise SystemExit('payload 文件与已验收清单不一致。')
        content = {}
        for entry in manifest['files']:
            name = entry['path']
            if not name.startswith('reframework/') or '..' in pathlib.PurePosixPath(name).parts:
                raise SystemExit('非法 payload 路径。')
            data = source.read('payload/'+name)
            if hashlib.sha256(data).hexdigest() != entry['sha256']:
                raise SystemExit('payload 已变更，请先重新验收并更新清单：'+name)
            content[name] = data
        for name in ['README.md','README_EN.md','THIRD_PARTY_NOTICES.md','验证记录.md','文件校验.json']:
            content[name] = source.read(name)
    content['BUILD_INFO.json'] = (json.dumps({
        'version':manifest['version'],
        'repository':'https://github.com/boyl/onimusha-achievement-tracker',
        'commit':head,
        'payload_manifest':'文件校验.json',
        'payload_files':len(manifest['files']),
    }, ensure_ascii=False, indent=2)+'\n').encode('utf-8')
    args.output_dir.mkdir(parents=True, exist_ok=True)
    target = args.output_dir/f"OnimushaAchievementTracker-{manifest['version']}-Nexus.zip"
    if target.exists():
        raise SystemExit('拒绝覆盖已有发布包：'+str(target))
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(content.items()):
            entry = zipfile.ZipInfo(name, date_time=(2026,9,13,0,0,0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = 0o100644 << 16
            archive.writestr(entry, data, compresslevel=9)
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None
        assert set(archive.namelist()) == set(content)
        for name, data in content.items():
            assert archive.read(name) == data
    digest=hashlib.sha256(target.read_bytes()).hexdigest()
    target.with_suffix('.zip.sha256').write_text(digest+'  '+target.name+'\n',encoding='utf-8')
    print(json.dumps({'path':str(target.resolve()),'commit':head,'files':len(content),
                      'bytes':target.stat().st_size,'sha256':digest},ensure_ascii=False,indent=2))

if __name__ == '__main__':
    main()
