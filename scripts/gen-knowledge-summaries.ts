import fs from "fs";
import path from "path";
import unified from "unified";
import { Node } from "unist";
import remarkParse from "remark-parse";

type AST = Node & {
  depth?: number;
  children?: AST[];
};

const blogsPath = "./pages/description";

const getSummaries = function (markdown: string) {
  // Parse to AST
  const ast = unified().use(remarkParse).parse(markdown) as AST;
  if (!ast.children) throw new Error("The root of AST must have children");

  const maybeTitleIndex = ast.children.findIndex(
    (child) => child.type === "heading" && child.depth === 1
  );
  if (maybeTitleIndex === -1) throw new Error("Title not found");
  const title = ast.children[maybeTitleIndex].children![0].value as string;

  // Find summaries' index
  const maybeSummaryIndex = ast.children.findIndex(
    (child) => child.children && child.children[0].value === "概要"
  );
  if (maybeSummaryIndex === -1) throw new Error("Summary not found");
  if (ast.children[maybeSummaryIndex + 1].type !== "list")
    throw new Error("Summary list must be after summary title");

  const summaries = ast.children[maybeSummaryIndex + 1].children?.map(
    (child) => child.children![0].children![0].value as string
  );

  return [title, summaries] as const;
};

fs.readdir(blogsPath, (err, files) => {
  if (err) throw err;

  const summaries = Object.fromEntries(
    files
      .filter((file) => file.endsWith(".mdx"))
      .map((file) => {
        const content = fs.readFileSync(path.join(blogsPath, file), "utf-8");
        return {
          link: file.replace(".mdx", ""),
          ...getSummaries(content),
        };
      })
  );

  fs.writeFile(
    "./generated/knowledge-summary.json",
    JSON.stringify(summaries, null, "  "),
    (err) => {
      if (err) throw err;
      console.log("Knowledge summaries generated.");
    }
  );
});
