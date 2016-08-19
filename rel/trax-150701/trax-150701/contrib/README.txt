

二股ソケット プログラム inspired by 松下幸之助's 二灯用クラスター

A.Kojima


Osana's trax(2015/2/5版) や traxfig と一緒に使って，2プレイヤー対戦を実現する補助プログラム　
2つの入出力デバイスを標準出力に接続し対戦環境を実現する．
シリアルポートとTCPポートを入出力デバイスに指定できる．(混在も可)

接続時に-W,-Bの送信を行う．
双方の着手の送受信の橋渡しを行う．(ICFPT2015のDesign Contestのプロトコルを参照)
双方の着手の着手データをまとめて標準出力に送る．

プロトコルチェック，ルールチェックはしていない．（行単位のデータの送受信のみ行う）

端末から人手で入力することも想定して，改行コードは 0x0a, 0x0d, 0x0d-0x0a, 0x0a-0x0d いずれでも動くようにした．
公式プロトコルでは改行は0x0aのみが許される．

Osana's blokus-host.c のコードの一部(タイムアウト付きread)を使用している．


◎動作環境

Cygwin, Ubuntu, CentOS, MacOSX で，簡単に動作確認しました．

（Linuxでうまく動かないシリアルデバイスもありました．ドライバが未サポートかも？）


◎使い方

 ./two-way-socket [-t <time_out>] <white serial_device or tcp_port> <black serial_device or tcp_port>

シリアルポート vs シリアルポート
 ./two-way-socket /dev/ttyS0 /dev/ttyS1 | ./trax

White /dev/ttyS0 ---+
                    +--- stdout --->
Black /dev/ttyS1 ---+


TCP ポート vs TCP ポート
 ./two-way-socket 10000 10001 | ./trax


White TCP 10000 ---+
                   +--- stdout --->
Black TCP 10001 ---+


シリアル vs TCP ポート
 ./two-way-socket /dev/ttyS0 10000 | ./trax


White /dev/ttyS0 ---+
                    +--- stdout --->
Black  TCP 10000 ---+


TCP port は 10000 - 10010 の範囲のいずれかを指定する．


USB-シリアル変換アダプタを使うときの例 (デバイス名を確認して指定する)
 ./two-way-socket /dev/ttyUSB0 /dev/ttyUSB1 | ./trax


Macでの実行例
 ./two-way-socket /dev/cu.usbserial 10000 | ./trax


テスト用なので，タイムアウトのデフォルト値は10000秒になっている．

タイムアウト(秒単位)を指定しての対戦（1秒での実行：コンテスト本番と同じ設定）
 ./two-way-socket -t 1 /dev/ttyS0 /dev/ttyS1 | ./trax


◎プログラムの停止方法

ルールチェックをしていないので，(ルール上の終局が分からないので)
デバイス関係のエラーが発生しないかぎり，two-way-socketは自分では止まらない．
デバイス関係のエラーが発生したら，exit(1);で止まる．
タイムアウトを指定した場合，時間切れになると停止する．
パイプの先のプログラムが，ルールチェックをして，停止するか，
起動端末でキーボードからControl-Cを入力して停止する．

基本的に自分で停止しないので，close処理を行っていない．
プロセスの停止時に，OS側でclose処理されることを仮定している．


◎traxfigを表示に使った対戦用スクリプト　interactive-traxfig.pl 

　単体使用　標準入力に着手を順番に入力
     ./interactive-traxfig.pl  

　two-way-socketと併用してのシリアルポート同士の対戦
     ./two-way-socket /dev/ttyS0 /dev/ttyS1 | ./interactive-traxfig.pl 


◎BUGS＆注意点

backspaceなどは効かない．(人手で打つときに失敗できない)
TeraTermのtelnetとの相性がよくない．３手目でハングアップする．

TeraTermのシリアルでは問題なく動く．
Windowsの標準のtelnetでは問題なく動く．
CentOSのtelnetでは問題なく動く．
Cygwinのtelnetでは問題なく動く．

traxfigは，受理するデータのチェックがあまい．
→審判ホスト，ルールチェックには使えない．別に専用のルーツチェッカーが必要．



◎ルールチェックプログラム，表示プログラム

Osana's trax の入手先

http://lut.eee.u-ryukyu.ac.jp/traxjp/index.html


traxfig の入手先

https://github.com/MartinMSPedersen/traxfig

