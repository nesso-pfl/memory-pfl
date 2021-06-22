import React, { useCallback, useState } from "react";
import styles from "./index.module.scss";
import Link from "next/link";
import { Layout } from "../components";
import { useListMemoriesResponse } from "../services/api";

export default function Search() {
  const [keyword, setKeyword] = useState("");
  const { data } = useListMemoriesResponse(keyword);

  const onChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => setKeyword(e.target.value),
    []
  );

  return (
    <Layout>
      <form className={styles.inputForm}>
        <input
          className={styles.searchInput}
          value={keyword}
          placeholder="Search"
          onChange={onChange}
        />
      </form>
      <ul className={styles.result}>
        {data?.map((memory) => (
          <Link key={memory.title} href={`memory/${memory.link}`} passHref>
            <li className={styles.resultItem} key={memory.title}>
              <h3>{memory.title}</h3>
              <ul>
                {memory.summaries.map((summary) => (
                  <li key={summary}>{summary}</li>
                ))}
              </ul>
            </li>
          </Link>
        ))}
      </ul>
    </Layout>
  );
}
