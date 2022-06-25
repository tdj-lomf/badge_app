# badge_app

Flutter project for AI Badge.

## 環境構築
1. 公式Tutorialに従って"4. Write your first app"くらいまで実施する(ここではVSCodeを使う)。  
    https://docs.flutter.dev/get-started/install  
2. コードをcloneして、VSCodeでフォルダを開く。  
3. 表示＞コマンドパレット で `Flutter: Change SDK` と入力し、SDKの場所を指定する（自動で検出されていると思う）。
4. コマンドパレットで `Flutter: Get Packages` を実行。 

## デバッグ実行
1. デバイスをPCに接続する。
2. 実行＞デバッグの開始 または Ctrl + F5 でデバッグモードのアプリがインストールされる。

## リリースビルド
1. デバイスをPCに接続する。
2. `flutter build apk --split-per-abi`
3. `flutter install`

apkをGitリポジトリで管理しているので、コードを編集していない場合は2を省略可能。  

アプリを起動してもうまく動かない場合、権限が足りない可能性がある。  
スマホのアプリ設定画面から権限を追加する。  


## コード編集
メインのコードは`(project)/lib/`に入っている。  
- main.dart:  
    bluetoothデバイスのスキャンや接続の画面。ほぼflutter_blue_plusのサンプル画面のまま。  
- widgets.dart: デバイス接続後のモータ操作画面。  
    _ServiceRowStateクラスのbuild関数で画面のレイアウトや操作コマンドを決めている。  

...