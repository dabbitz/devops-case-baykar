import { MongoClient } from "mongodb";

const connectionString = process.env.ATLAS_URI || "mongodb://localhost:27017";

const client = new MongoClient(connectionString);

let conn;

try {
  console.log("Connecting to MongoDB Atlas...");
  conn = await client.connect();
} catch (e) {
  console.error("Database connection failed: ", e);
  process.exit(1);
}

let db = conn.db("sample_training");

export default db;
