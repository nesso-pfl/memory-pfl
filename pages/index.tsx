import React, { useCallback, useState } from "react";
import styles from "./index.module.scss";
import Link from "next/link";
import { Layout } from "../components";
import { useListKnowledgesResponse } from "../services/api";

export default function Search() {
  const [keyword, setKeyword] = useState("");
  const { data } = useListKnowledgesResponse(keyword);

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
        {data?.map((knowledge) => (
          <Link
            key={knowledge.title}
            href={`description/${knowledge.link}`}
            passHref
          >
            <li className={styles.resultItem} key={knowledge.title}>
              <h3>{knowledge.title}</h3>
              <ul>
                {knowledge.summaries.map((summary) => (
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
