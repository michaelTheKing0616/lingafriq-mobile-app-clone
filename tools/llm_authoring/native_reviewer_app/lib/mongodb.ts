import { MongoClient, Db, Collection } from "mongodb";

const uri = process.env.MONGODB_URI;
if (!uri) {
  throw new Error("MONGODB_URI is required");
}

declare global {
  // eslint-disable-next-line no-var
  var _mongoClient: MongoClient | undefined;
}

const client = global._mongoClient ?? new MongoClient(uri);
if (process.env.NODE_ENV !== "production") {
  global._mongoClient = client;
}

export type ReviewDraft = {
  _id?: string;
  draftId: string;
  kind: "curriculum" | "games";
  lang: string;
  level: string;
  status: "pending_review" | "changes_requested" | "approved" | "rejected";
  payload: Record<string, unknown>;
  sourcePath: string;
  createdAt: string;
  updatedAt: string;
  reviewer?: string;
  reviewerNotes?: string;
  audioPreviewUrls?: string[];
};

export async function getDb(): Promise<Db> {
  await client.connect();
  return client.db();
}

export async function draftsCollection(): Promise<Collection<ReviewDraft>> {
  const db = await getDb();
  return db.collection<ReviewDraft>("authoring_drafts");
}
