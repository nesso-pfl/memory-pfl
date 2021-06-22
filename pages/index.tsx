import React, { useCallback, useState } from "react";
import styles from "./index.module.scss";
import Link from "next/link";
import { useRouter } from "next/router";
import { Layout } from "../components";
import { useListMemoriesResponse } from "../services/api";
import { queryParamToString } from "../services/router";

const Search: React.VFC = () => {
  const { query } = useRouter();
  const [keyword, setKeyword] = useState<string>(() =>
    queryParamToString(query.keyword ?? "")
  );
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
};

export default Search;
