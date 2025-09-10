// server.mjs (само горната част)
import express from "express";
import cors from "cors";
import jwt from "jsonwebtoken";
import Database from "better-sqlite3";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const DB_PATH = path.join(__dirname, "data.db"); // <-- винаги в папката на server.mjs

const app = express();
const PORT = process.env.PORT || 8080;
const JWT_SECRET = process.env.JWT_SECRET || "super-secret-change";
const FRONTEND_ORIGIN = process.env.FRONTEND_ORIGIN || "http://localhost:3000";

const db = new Database(DB_PATH);

// DB init
const db = new Database("./data.db");
db.exec(`
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  firstName TEXT,
  lastName TEXT,
  phone TEXT,
  email TEXT,
  address TEXT,
  created INTEGER
);
CREATE TABLE IF NOT EXISTS carts (
  userId TEXT PRIMARY KEY,
  payload TEXT,
  updated INTEGER
);
`);

// Middleware
app.use(cors({ origin: FRONTEND_ORIGIN, credentials: true }));
app.use(express.json({ limit: "1mb" }));

// Helpers
const upsertUser = db.prepare(`
INSERT INTO users (id, firstName, lastName, phone, email, address, created)
VALUES (@id,@firstName,@lastName,@phone,@email,@address,@created)
ON CONFLICT(id) DO UPDATE SET
  firstName=excluded.firstName,
  lastName=excluded.lastName,
  phone=excluded.phone,
  email=excluded.email,
  address=excluded.address
`);
const upsertCart = db.prepare(`
INSERT INTO carts (userId,payload,updated)
VALUES (@userId,@payload,@updated)
ON CONFLICT(userId) DO UPDATE SET
  payload=excluded.payload,
  updated=excluded.updated
`);
const getUser = db.prepare(`SELECT * FROM users WHERE id=?`);

// Routes
app.post("/api/register",(req,res)=>{
  try{
    const {user,password,cart}=req.body;
    if(!user||!user.id||!user.firstName||!user.email){
      return res.status(400).json({ok:false,message:"Invalid payload"});
    }

    upsertUser.run(user);
    if(Array.isArray(cart)){
      upsertCart.run({userId:user.id,payload:JSON.stringify(cart),updated:Date.now()});
    }

    const token=jwt.sign({sub:user.id,email:user.email},JWT_SECRET,{expiresIn:"30d"});
    const dbUser=getUser.get(user.id);

    res.json({ok:true,token,user:dbUser});
  }catch(err){
    console.error(err);
    res.status(500).json({ok:false,message:"Server error"});
  }
});

app.listen(PORT,()=>console.log(`API listening on http://localhost:${PORT}`));
