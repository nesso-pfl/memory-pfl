export const queryParamToString = (queryParam: string | string[]) => {
  switch (typeof queryParam) {
    case "string":
      return queryParam;
    case "object":
      return queryParam[0];
  }
};
