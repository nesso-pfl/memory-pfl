import useSWR from "swr";

const fetcher = (url: string) => fetch(url).then((res) => res.json());

export const useResponse = <T>(path: string) => {
  return useSWR<T>(path, fetcher);
};
