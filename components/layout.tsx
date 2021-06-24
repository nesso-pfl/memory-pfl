import React from "react";
import Head from "next/head";
import { Header } from "./header";
import styles from "./layout.module.scss";

type Props = {
  title: string;
};

export const Layout: React.FC<Props> = ({ children, title }) => {
  return (
    <>
      <Head>
        <title>{title} | memory-pfl</title>
      </Head>
      <div className={styles.container}>
        <Header className={styles.header} />
        <main className={styles.main}>{children}</main>
      </div>
    </>
  );
};
