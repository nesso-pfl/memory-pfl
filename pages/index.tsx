import React, { useCallback, useState } from "react";
import useSWR from "swr";
import { Layout } from "../components";

const fetcher = (url: string) => fetch(url).then((res) => res.json());

const useListKnowledges = (keyword: string) => {
  return useSWR(`/api/list-knowledges?keyword=${keyword}`, fetcher);
};

export default function Search() {
  const [keyword, setKeyword] = useState("");
  const { data } = useListKnowledges(keyword);
  console.log(data);

  const onChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => setKeyword(e.target.value),
    []
  );

  return (
    <Layout>
      <form>
        <input value={keyword} onChange={onChange} />
      </form>
    </Layout>
  );
}
