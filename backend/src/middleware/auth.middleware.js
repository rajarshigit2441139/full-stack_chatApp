import jwt from "jsonwebtoken";
import User from "../models/user.model.js";
import { authEvents } from "../lib/metrics.js"; 

export const protectRoute = async (req, res, next) => {
  try {
    const token = req.cookies.jwt;

    if (!token) {
      authEvents.inc({ event: "auth_failure" }); 
      return res.status(401).json({ message: "Unauthorized - No Token Provided" });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (!decoded) {
      authEvents.inc({ event: "auth_failure" }); 
      return res.status(401).json({ message: "Unauthorized - Invalid Token" });
    }

    const user = await User.findById(decoded.userId).select("-password");

    if (!user) {
      authEvents.inc({ event: "auth_failure" }); 
      return res.status(404).json({ message: "User not found" });
    }

    req.user = user;

    next();
  } catch (error) {
    authEvents.inc({ event: "auth_failure" }); 
    console.log("Error in protectRoute middleware: ", error.message);
    res.status(500).json({ message: "Internal server error" });
  }
};