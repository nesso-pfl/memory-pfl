import React from "react";
import Link from "next/link";
import clsx from "clsx";
import styles from "./header.module.scss";

type Props = {
  className?: string;
};

export const Header: React.VFC<Props> = ({ className }) => {
  return (
    <header className={clsx(className, styles.header)}>
      <Link href="/">
        <a className={styles.topLink}>Memory-pfl</a>
      </Link>
    </header>
  );
};
