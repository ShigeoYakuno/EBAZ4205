# EBAZ4205　ZYNQ　開発備忘録　ハードウェア

・Aliexpressで購入する。いくつかバージョンがあるようだ。  
・私の購入したバージョンは、MicroSDソケット付き、JTAG用ピンヘッダ付き、PL用クロックX5付きのもの。

クロック用のオシレータは以下の2種類が実装されていた。  
<br>
■PSクロック　X8 33.3MHz
<br>
<img width="434" alt="image" src="https://github.com/user-attachments/assets/41e27ece-49d2-435e-8050-803f9c3d6646" />
<br>
<img width="401" alt="image" src="https://github.com/user-attachments/assets/72f8e785-c771-42f0-8867-aec8f8fad66d" />  
<br>
<br>
■PLクロック X5 50.0MHz  
<br>
R1372とL29がついている。ENはopenまたはプルアップで有効。プルダウンで無効
<br>
<img width="353" alt="image" src="https://github.com/user-attachments/assets/cc3e8466-f672-44fc-adfe-9438e7410c75" />
<br>
<img width="401" alt="image" src="https://github.com/user-attachments/assets/be781fa3-532f-4c4f-a6fd-d8e7abed03b4" />  
<br>
<br>
<br>
★ボードの改造について
<br>
■電源コネクタ  
MOLEXのコネクタより12V給電する場合は、D24ダイオードが未実装なので、ジャンパする。
<br>
<img width="284" alt="image" src="https://github.com/user-attachments/assets/e340ca8c-70f9-4ede-9f31-dd1123df31f9" />
<br>
■リセットSW
<br>
下記の素晴らしいサイトを例にフォトカプラをSWを交換する。
https://qiita.com/kan573/items/c4dac8908e1a86d8fce6  
<br>
![image](https://github.com/user-attachments/assets/8b068b06-6701-4a14-9e22-a56b38c47530)
<br>
SWはS2とS3がついていたが、PLからアクセスできないようだ。PS,PLそれぞれでしかアクセスできないものがあるらしい。  
上記に習って、SWを取り付ける
<br>
<br>
