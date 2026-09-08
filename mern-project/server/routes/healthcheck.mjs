import express from "express";
const router = express.Router();

router.get("/", async (req, res) => {
  const status = {
    uptime: process.uptime(),
    message: "OK",
    timestamp: Date.now(),
  };

  return res.status(200).json(status);
});

export default router;