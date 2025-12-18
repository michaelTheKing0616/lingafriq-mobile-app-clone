export type Message = {
  id: string;
  sender: string;
  body: string;
  lang?: string;
  meta?: Record<string, any>;
};

