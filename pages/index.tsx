import React, { useCallback, useState } from "react";
import { Layout } from "../components";
import { useListKnowledgesResponse } from "../services/api";

export default function Search() {
  const [keyword, setKeyword] = useState("");
  const { data } = useListKnowledgesResponse(keyword);

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
