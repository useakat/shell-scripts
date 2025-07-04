#!/bin/bash

# インデックス生成スクリプトを更新して、reportsディレクトリ内のファイルのみを表示するようにする

# 更新するファイル
SCRIPT_PATH="/home/ubuntu/generate_index.py"

# バックアップを作成
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "cp $SCRIPT_PATH ${SCRIPT_PATH}.bak"

# スクリプトを更新 - reportsディレクトリ内のファイルのみを表示するように変更
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "cat > $SCRIPT_PATH" << 'EOF'
#!/usr/bin/env python3
import boto3
import os
import datetime
import re
from collections import defaultdict

# S3バケット名
S3_BUCKET = "html-report-bucket-example"
# レポートディレクトリのプレフィックス
REPORTS_PREFIX = "reports/"

def get_s3_objects():
    """S3バケットからオブジェクトのリストを取得"""
    s3_client = boto3.client('s3')
    objects = []
    
    # S3オブジェクトを取得
    paginator = s3_client.get_paginator('list_objects_v2')
    pages = paginator.paginate(Bucket=S3_BUCKET, Prefix=REPORTS_PREFIX)
    
    for page in pages:
        if 'Contents' in page:
            for obj in page['Contents']:
                # ディレクトリ自体は除外
                if obj['Key'] != REPORTS_PREFIX:
                    objects.append({
                        'key': obj['Key'],
                        'size': obj['Size'],
                        'last_modified': obj['LastModified']
                    })
    
    return objects

def format_size(size):
    """ファイルサイズを読みやすい形式に変換"""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size < 1024.0:
            return f"{size:.1f} {unit}"
        size /= 1024.0
    return f"{size:.1f} TB"

def create_tree_structure(objects):
    """オブジェクトのリストからツリー構造を作成"""
    tree = defaultdict(list)
    
    for obj in objects:
        key = obj['key']
        if key.startswith(REPORTS_PREFIX):
            # プレフィックスを除去
            rel_path = key[len(REPORTS_PREFIX):]
            if rel_path:  # 空でない場合のみ追加
                # ファイル名とディレクトリを分離
                parts = rel_path.split('/')
                if len(parts) == 1:  # ルートディレクトリのファイル
                    tree[''].append({
                        'name': parts[0],
                        'path': key,
                        'size': format_size(obj['size']),
                        'last_modified': obj['last_modified'].strftime('%Y-%m-%d %H:%M:%S')
                    })
                else:
                    # サブディレクトリのファイル
                    dir_path = '/'.join(parts[:-1])
                    tree[dir_path].append({
                        'name': parts[-1],
                        'path': key,
                        'size': format_size(obj['size']),
                        'last_modified': obj['last_modified'].strftime('%Y-%m-%d %H:%M:%S')
                    })
    
    return tree

def generate_html(tree):
    """ツリー構造からHTMLを生成（フォルダを先に表示）"""
    html = """<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RNAseq Reports Directory</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1 {
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .tree {
            margin-left: 20px;
        }
        .tree-item {
            margin: 5px 0;
        }
        .folder {
            cursor: pointer;
            font-weight: bold;
            color: #2980b9;
        }
        .folder:before {
            content: "📁 ";
        }
        .folder.open:before {
            content: "📂 ";
        }
        .file {
            margin-left: 20px;
        }
        .file:before {
            content: "📄 ";
        }
        .file a {
            color: #3498db;
            text-decoration: none;
        }
        .file a:hover {
            text-decoration: underline;
        }
        .hidden {
            display: none;
        }
        .file-info {
            font-size: 0.8em;
            color: #7f8c8d;
            margin-left: 10px;
        }
        .back-link {
            display: inline-block;
            margin-bottom: 20px;
            padding: 8px 15px;
            background-color: #3498db;
            color: white;
            text-decoration: none;
            border-radius: 4px;
        }
        .back-link:hover {
            background-color: #2980b9;
        }
        .search-container {
            margin-bottom: 20px;
        }
        #search-input {
            padding: 8px;
            width: 300px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        .timestamp {
            font-size: 0.8em;
            color: #95a5a6;
            margin-top: 20px;
        }
        .section-header {
            font-size: 1.2em;
            font-weight: bold;
            margin-top: 20px;
            margin-bottom: 10px;
            color: #2c3e50;
        }
    </style>
</head>
<body>
    <div class="container">
        <a href="/" class="back-link">← ホームに戻る</a>
        <h1>RNAseq Reports Directory</h1>
        
        <div class="search-container">
            <input type="text" id="search-input" placeholder="ファイル名で検索...">
        </div>
        
        <div class="tree" id="file-tree">
"""
    
    # サブディレクトリとそのファイル（フォルダを先に表示）
    dirs = [d for d in tree.keys() if d != '']
    if dirs:
        html += """
        <div class="section-header">フォルダ</div>
        """
        
        for dir_path in sorted(dirs):
            dir_name = dir_path.split('/')[-1] if dir_path else "Root"
            html += f"""
        <div class="tree-item">
            <div class="folder" onclick="toggleFolder(this)">{dir_name}</div>
            <div class="tree folder-contents hidden">
            """
            
            for file in sorted(tree[dir_path], key=lambda x: x['name'].lower()):
                html += f"""
                <div class="tree-item file">
                    <a href="/{file['path']}" target="_blank">{file['name']}</a>
                    <span class="file-info">{file['size']} - {file['last_modified']}</span>
                </div>
                """
            
            html += """
            </div>
        </div>
            """
    
    # ルートディレクトリのファイル
    if '' in tree:
        html += """
        <div class="section-header">ファイル</div>
        """
        
        for file in sorted(tree[''], key=lambda x: x['name'].lower()):
            html += f"""
        <div class="tree-item file">
            <a href="/{file['path']}" target="_blank">{file['name']}</a>
            <span class="file-info">{file['size']} - {file['last_modified']}</span>
        </div>
            """
    
    # 現在の日時を追加
    current_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    html += f"""
        <div class="timestamp">最終更新: {current_time}</div>
    </div>
    
    <script>
        function toggleFolder(element) {{
            element.classList.toggle('open');
            var content = element.nextElementSibling;
            content.classList.toggle('hidden');
        }}
        
        // 初期状態でフォルダを開く
        window.onload = function() {{
            var folders = document.querySelectorAll('.folder');
            folders.forEach(function(folder) {{
                folder.classList.add('open');
                folder.nextElementSibling.classList.remove('hidden');
            }});
        }};
        
        document.getElementById('search-input').addEventListener('input', function(e) {{
            var searchTerm = e.target.value.toLowerCase();
            var fileItems = document.querySelectorAll('.file');
            var sectionHeaders = document.querySelectorAll('.section-header');
            
            // 検索語が空の場合、セクションヘッダーを表示
            if (searchTerm === '') {{
                sectionHeaders.forEach(function(header) {{
                    header.style.display = '';
                }});
            }} else {{
                // 検索中はセクションヘッダーを非表示
                sectionHeaders.forEach(function(header) {{
                    header.style.display = 'none';
                }});
            }}
            
            fileItems.forEach(function(item) {{
                var fileName = item.querySelector('a').textContent.toLowerCase();
                var parentFolder = item.closest('.tree-item').querySelector('.folder');
                
                if (fileName.includes(searchTerm)) {{
                    item.style.display = '';
                    if (parentFolder) {{
                        parentFolder.nextElementSibling.classList.remove('hidden');
                        parentFolder.classList.add('open');
                        parentFolder.parentElement.style.display = '';
                    }}
                }} else {{
                    item.style.display = 'none';
                }}
            }});
            
            // 空のフォルダを非表示
            var folders = document.querySelectorAll('.folder');
            folders.forEach(function(folder) {{
                var contents = folder.nextElementSibling;
                var visibleFiles = Array.from(contents.querySelectorAll('.file')).filter(function(file) {{
                    return file.style.display !== 'none';
                }});
                
                if (visibleFiles.length === 0) {{
                    folder.parentElement.style.display = 'none';
                }} else {{
                    folder.parentElement.style.display = '';
                }}
            }});
        }});
    </script>
</body>
</html>
"""
    
    return html

def create_main_index():
    """メインのindex.htmlを作成"""
    html = """<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RNAseq Analysis Portal</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 0;
            color: #333;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        header {
            background-color: #2c3e50;
            color: white;
            padding: 20px 0;
            text-align: center;
        }
        h1 {
            margin: 0;
        }
        .content {
            background-color: white;
            padding: 20px;
            margin-top: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .card {
            background-color: #f9f9f9;
            border-left: 4px solid #3498db;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 4px;
            transition: transform 0.3s ease;
        }
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        .card h2 {
            margin-top: 0;
            color: #2c3e50;
        }
        .card p {
            color: #7f8c8d;
        }
        .btn {
            display: inline-block;
            background-color: #3498db;
            color: white;
            padding: 8px 15px;
            text-decoration: none;
            border-radius: 4px;
            transition: background-color 0.3s ease;
        }
        .btn:hover {
            background-color: #2980b9;
        }
        footer {
            text-align: center;
            margin-top: 30px;
            padding: 20px 0;
            color: #7f8c8d;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <header>
        <div class="container">
            <h1>RNAseq Analysis Portal</h1>
        </div>
    </header>
    
    <div class="container">
        <div class="content">
            <div class="card">
                <h2>レポートディレクトリ</h2>
                <p>RNAseq解析の結果レポートを閲覧できます。レポートファイルの一覧を表示します。</p>
                <a href="/reports-tree.html" class="btn">レポートを表示</a>
            </div>
            
            <div class="card">
                <h2>マルチQCレポート</h2>
                <p>サンプル全体のクオリティコントロールレポートを表示します。</p>
                <a href="/reports/multiqc_report.html" class="btn">MultiQCレポートを表示</a>
            </div>
            
            <div class="card">
                <h2>FastQCレポート</h2>
                <p>各サンプルのFastQCレポートにアクセスできます。</p>
                <a href="/reports-tree.html#fastqc" class="btn">FastQCレポートを表示</a>
            </div>
        </div>
    </div>
    
    <footer>
        <div class="container">
            <p>&copy; 2025 RNAseq Analysis Team. All rights reserved.</p>
        </div>
    </footer>
</body>
</html>
"""
    return html

def upload_to_s3(html_content, key):
    """HTMLコンテンツをS3にアップロード"""
    s3_client = boto3.client('s3')
    s3_client.put_object(
        Bucket=S3_BUCKET,
        Key=key,
        Body=html_content,
        ContentType='text/html'
    )
    print(f"Uploaded {key} to S3 bucket {S3_BUCKET}")

def main():
    # S3からオブジェクトを取得
    objects = get_s3_objects()
    
    # ツリー構造を作成
    tree = create_tree_structure(objects)
    
    # HTMLを生成（フォルダを先に表示）
    html = generate_html(tree)
    
    # レポートツリーページをS3にアップロード
    upload_to_s3(html, "reports-tree.html")
    
    # メインのindex.htmlを作成
    main_index = create_main_index()
    
    # メインのindex.htmlをS3にアップロード
    upload_to_s3(main_index, "index.html")
    
    print("インデックスページの生成と更新が完了しました。")

if __name__ == "__main__":
    main()
EOF

# 更新されたスクリプトを表示
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "cat $SCRIPT_PATH | head -n 20"

# 更新後にインデックスを再生成
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "python3 /home/ubuntu/generate_index.py"

echo "インデックス生成スクリプトを更新し、インデックスを再生成しました。"
