import { useResponse } from "./useResponse";
import * as mdxs from "../../pages/memory/_index";
import summaries from "../../generated/memory-summaries.json";
import type { NextApiRequest, NextApiResponse } from "next";

type Memory = {
  title: string;
  link: string;
  summaries: string[];
};

type Response = Memory[];

const castString = (queryParam: string | string[]) =>
  typeof queryParam === "string" ? queryParam : queryParam[0];

export function listMemories(
  { query }: NextApiRequest,
  res: NextApiResponse<Response>
) {
  const keyword = castString(query.keyword).toLowerCase();
  const searchResult = Object.values(mdxs)
    .filter(
      (mdx) =>
        mdx.meta.title.toLowerCase().includes(keyword) ||
        mdx.meta.tags.some((tag) => tag.toLowerCase().includes(keyword))
    )
    .map(
      (mdx) => summaries.find((summary) => summary.title === mdx.meta.title)!
    );
  res.status(200).json(searchResult);
}

export const useListMemoriesResponse = (keyword: string) => {
  return useResponse<Response>(`/api/list-memories?keyword=${keyword}`);
};
