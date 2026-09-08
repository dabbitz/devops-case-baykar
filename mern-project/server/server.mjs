import express from "express";
import cors from "cors";
import "./loadEnvironment.mjs";
import records from "./routes/record.mjs";
import healthcheck from "./routes/healthcheck.mjs";

const PORT = 5050;
const app = express();

app.use(cors({
  origin: process.env.ALLOWED_ORIGIN
}));
app.use(express.json());

app.use("/record", records);
app.use("/healthcheck", healthcheck);

// start the Express server
app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
