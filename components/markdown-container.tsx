import React from "react";
import styles from "./markdown-container.module.scss";

export const MarkdownContainer: React.FC = ({ children }) => {
  return <div className={styles.container}>{children}</div>;
};
