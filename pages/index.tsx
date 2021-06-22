import React, { useCallback, useState } from "react";
import useSWR from "swr";
import { Layout } from "../components";
import type { Knowledge } from "./api/list-knowledges";

const fetcher = (url: string) => fetch(url).then((res) => res.json());

const useListKnowledges = (keyword: string) => {
  return useSWR<Knowledge[]>(
    `/api/list-knowledges?keyword=${keyword}`,
    fetcher
  );
};

export default function Search() {
  const [keyword, setKeyword] = useState("");
  const { data } = useListKnowledges(keyword);

  const onChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => setKeyword(e.target.value),
    []
  );

  console.log(data);
  return (
    <Layout>
      <form>
        <input value={keyword} onChange={onChange} />
      </form>
      <div>
        {data?.map((knowledge) => (
          <div key={knowledge.title}>
            <h3>{knowledge.title}</h3>
            <ul>
              {knowledge.summaries.map((summary) => (
                <li key={summary}>{summary}</li>
              ))}
            </ul>
          </div>
        ))}
      </div>
    </Layout>
  );
}
