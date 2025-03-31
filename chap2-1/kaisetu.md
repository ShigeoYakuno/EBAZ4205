####  チャプター2-1のポイント
<br>
<br>
■制約ファイル(xdc)
<br>
<br>
![image](https://github.com/user-attachments/assets/0d4d2c08-b228-41f3-bc76-ff2bd02c0c19)
<br>
<br>
上記のクロックの設定では、X5の50MHzを使って、PLのN18へ供給している。
<br>
それぞれの意味を考える
<br>
<br>
★set_property PACKAGE_PIN N18 [get_ports { CLK }]
<br>
この行は、FPGAの物理的なピンと、Vivado上の信号名を関連付けている。  
<br>
get_ports { CLK } は、Vivadoプロジェクト内で CLK という名前のポート（信号）を取得する。  
<br>
set_property PACKAGE_PIN N18 は、チップのピン配置における N18 ピンに割り当てる。  
<br>
つまりこの行は「外部から供給されるクロック信号が、FPGAのN18ピンに接続されており、Vivado上では CLK という名前で扱う」ということをVivadoに伝えている。
<br>
<br>
<br>
★set_property IOSTANDARD LVCMOS33 [get_ports { CLK }]
<br>
この行は、CLK ポートの入出力規格（IOSTANDARD）を設定する。
<br>
LVCMOS33 は、3.3VのLVCMOS（Low-Voltage CMOS）規格を意味する。
<br>
つまりこの行は「N18ピンに入力されるクロック信号は、3.3VのLVCMOSレベルである」ということをVivadoに伝えている。
<br>
<br>
<br>
★create_clock -add -name sys_clk_pin -period 20.000 -waveform {0 10} [get_ports { CLK }]
<br>
この行は、CLK ポートに入力されるクロック信号の特性をVivadoに伝えている。
<br>
create_clock -add -name sys_clk_pin は、新しいクロック信号を定義し、sys_clk_pin という名前を付ける。
<br>
-period 20.000 は、クロックの周期を20.000ナノ秒（ns）に設定します。これは、クロックの周波数が50MHz（1 / 20ns）であることを意味する。
<br>
-waveform {0 10} は、クロックのデューティサイクル（HighレベルとLowレベルの時間比率）を設定する。
<br>
{0 10} は、Highレベルが0nsから10ns、Lowレベルが10nsから20nsであることを意味し、50%のデューティサイクルを表す。
<br>
[get_ports { CLK }] は、クロック信号を適用するポートを指定する。
<br>
つまり、この行は「N18ピンに入力されるクロック信号は、50MHzの周波数で、デューティサイクルが50%である」ということをVivadoに伝える。
<br>

<br>
<br>
■HDLファイル(.v)
<br>
<br>
![image](https://github.com/user-attachments/assets/3fe9e105-fbf9-4e03-931f-6ea79b660569)
<br>
<br>
<br>
<br>
■クロック入力部
always @( posedge CLK ) begin ... end: クロックの立ち上がりエッジで動作するalwaysブロック。
<br>
if ( RST ) cnt24 <= 24'h0;: リセット信号RSTがHighの場合、カウンタcnt24を0にリセットする。
<br>
ちなみにSWを改造していなかった当初は、VCCにプルアップされており、常にリセット状態だった。
<br>
LEDのパターンが変わらず、クロック供給などを疑ったが、原因はリセットが常にハイレベルだったためであった。
<br>
else cnt24 <= cnt24 + 1'h1;: リセット信号がLowの場合は、カウンタcnt24を1ずつインクリメント。
<br>
wire ledcnten = (cnt24==24'hffffff);: カウンタcnt24が最大値(24'hffffff)に達したときにHighになる信号ledcntenを生成。

★オーバーフロー時間の計算
<br>
カウンタの最大値: 24ビットカウンタの最大値は、2<sup>24</sup> - 1 = 16,777,215。
<br>
クロック周期: 制約ファイルから、クロック周期は20ns(50Mhz)。
<br>
16,777,215 * 20ns = 335,544,300ns = 335.5443ms = 0.3355443秒
<br>
したがって、24ビットカウンタがオーバーフローするまでの時間は、約0.335秒。
