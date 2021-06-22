import type { NextApiRequest, NextApiResponse } from "next";
import * as mdxs from "../description/_index";
import summaries from "../../generated/knowledge-summary.json";

type Knowledge = {
  title: string;
  link: string;
  summaries: string[];
};

type Data = Knowledge[];

const castString = (queryParam: string | string[]) =>
  typeof queryParam === "string" ? queryParam : queryParam[0];

export default function listKnowledges(
  { query }: NextApiRequest,
  res: NextApiResponse<Data>
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
