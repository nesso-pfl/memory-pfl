import React from "react";
import { Header } from "./header";
import styles from "./layout.module.scss";

export const Layout: React.FC = ({ children }) => {
  return (
    <div className={styles.container}>
      <Header className={styles.header} />
      <main className={styles.main}>{children}</main>
    </div>
  );
};
