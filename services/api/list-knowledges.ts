import { useResponse } from "./useResponse";
import * as mdxs from "../../pages/description/_index";
import summaries from "../../generated/knowledge-summary.json";
import type { NextApiRequest, NextApiResponse } from "next";

type Knowledge = {
  title: string;
  link: string;
  summaries: string[];
};

type Response = Knowledge[];

const castString = (queryParam: string | string[]) =>
  typeof queryParam === "string" ? queryParam : queryParam[0];

export function listKnowledges(
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

export const useListKnowledgesResponse = (keyword: string) => {
  return useResponse<Response>(`/api/list-knowledges?keyword=${keyword}`);
};
