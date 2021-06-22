import React from "react";
import Link from "next/link";

type Props = {
  tags: string[];
};

export const Tags: React.VFC<Props> = ({ tags }) => {
  return (
    <ul>
      {tags.map((tag) => (
        <li key={tag}>
          <Link href={`/memory/${tag}`}>{tag}</Link>
        </li>
      ))}
    </ul>
  );
};
