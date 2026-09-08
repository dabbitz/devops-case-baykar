import express from "express";
import db from "../db/conn.mjs";
import { ObjectId } from "mongodb";

const router = express.Router();

// This section will help you get a list of all the records.
router.get("/", async (req, res) => {
  try{
    let collection = await db.collection("records");
    let results = await collection.find({}).toArray();

    res.status(200).send(results);
  }
  catch(error){
    console.error("Failed to fetch records: ", error);

    return res.status(500).json({
      error: "Failed to fetch records.",
    });
  }
});

// This section will help you get a single record by id
router.get("/:id", async (req, res) => {
  const {id} = req.params;

  if(!ObjectId.isValid(id)){
    return res.status(400).json({
      error: "Invalid Id.",
    });
  }

  try{
    let collection = await db.collection("records");
    let query = {_id: new ObjectId(id)};
    let result = await collection.findOne(query);

    if (!result){
      return res.status(404).json({
        error: "Record not found.",
      });
    }

    return res.status(200).json(result);
  }
  catch(error){
    console.error("Failed to fetch record:", error);

    return res.status(500).json({
      error: "Failed to fetch record.",
    });
  }
});

// This section will help you create a new record.
router.post("/", async (req, res) => {
  const {name, position, level} = req.body;

  if(typeof name !== "string" || name.trim() === "" || 
    typeof position !== "string" || position.trim() === "" || 
    !["Intern", "Junior", "Senior"].includes(level)){
    
    return res.status(400).json({
      error: "Invalid entry.",
    });
  }

  let newDocument = {
    name: name.trim(),
    position: position.trim(),
    level: level,
  };

  try{
    let collection = await db.collection("records");
    let result = await collection.insertOne(newDocument);
    
    return res.status(201).send(result);
  }
  catch(error){
    console.error("Failed to create a new record: ", error);

    return res.status(500).json({
      error: "Failed to create a new record.",
    });
  }
});

// This section will help you update a record by id.
router.patch("/:id", async (req, res) => {
  const {id} = req.params;
  const {name, position, level} = req.body;

  if(!ObjectId.isValid(id)){
    return res.status(400).json({
      error: "Invalid record Id.",
    });
  }

  if(typeof name !== "string" || name.trim() === "" ||
  typeof position !== "string" || position.trim() === "" ||
  !["Intern", "Junior", "Senior"].includes(level)){
    return res.status(400).json({
      error: "Invalid record data.",
    });
  }

  try {
    const query = { _id: new ObjectId(id) };
    const updates =  {
      $set: {
        name: name.trim(),
        position: position.trim(),
        level: level
      }
    };

    let collection = await db.collection("records");
    let result = await collection.updateOne(query, updates);

    if(result.matchedCount === 0){
      return res.status(404).json({
        error: "Record not found.",
      });
    }

    return res.status(200).json(result);
  }
  catch(error){
    console.error("Failed to update record: ", error);

    return res.status(500).json({
      error: "Failed to update record.",
    });
  }

});

// This section will help you delete a record
router.delete("/:id", async (req, res) => {
  const {id} = req.params;

  if(!ObjectId.isValid(id)){
    return res.status(400).json({
      error: "Invalid record Id.",
    });
  }

  try{
    const query = { _id: new ObjectId(id) };
    const collection = db.collection("records");
    
    let result = await collection.deleteOne(query);

    if(result.deletedCount === 0){
      return res.status(404).json({
        error: "Record not found.",
      });
    }

    return res.status(200).json(result);
  }
  catch(error){
    console.error("Failed to delete record: ", error);

    return res.status(500).json({
      error: "Failed to delete record.",
    });
  }
});

export default router;