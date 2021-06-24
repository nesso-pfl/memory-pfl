import Document, { Html, Head, Main, NextScript } from "next/document";

type Props = {
  styleTags: any;
};

export default class MyDocument extends Document<Props> {
  render() {
    return (
      <Html lang="ja">
        <Head>
          <meta
            name="description"
            content="nesso-pfl が調べたものを忘れないように、或いは忘れてもすぐ思い出せるように記憶を書き留めておくメモアプリのトップページ"
          />
        </Head>
        <body>
          <Main />
          <NextScript />
        </body>
      </Html>
    );
  }
}
