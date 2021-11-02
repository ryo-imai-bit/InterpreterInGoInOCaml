# InterpreterInGoInOCaml

**[ 完成 ]**  
[InterpreterInGo](https://www.oreilly.co.jp/books/9784873118222/)のOCaml実装


## 経過

- duneでlocalのlexerのlibararyが読み込めなかった問題。プロジェクトルートにdune関係なくビルドしたlexer.cmaとかが残ってたせいだった

## todo

- リファクタ
  - parseの相互再帰的部分がうまく細かい単位に分割できないのでリファクタ考える
  - エラーの表示が親切でない、多くの場合出てこない
  - (もとの実装に寄せたが、OCmalの実装としてより自然にする)
- マクロ
- ハッシュ
- for文 or while文
