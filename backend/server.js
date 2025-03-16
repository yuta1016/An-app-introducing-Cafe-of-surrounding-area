const express = require("express");
const dotenv = require("dotenv");
const cors = require("cors");
const axios = require("axios");

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

//Qiitaから参照ぱちぱち
const path = require('path');
/// .envから環境変数取り込み
require('dotenv').config({
  path: path.resolve(__dirname, '../.env')
});
/////

console.log("API:::", process.env.GOOGLE_MAPS_API_KEY);

app.use(cors());

app.get("/", (req, res) => {
    res.send("Welcome to the API server!");
});

app.get("/google_maps_api_key", (req, res) => {
    const apiKey = process.env.GOOGLE_MAPS_API_KEY;
    if(!apiKey){
        return res.status(500).json({ error: 'API key not found' });
    }

    res.json({apiKey});
});

app.get("/google_places_api_key", async (req, res) => {
    const apiKey = process.env.GOOGLE_PLACES_API_KEY;
    if(!apiKey){
        return res.status(500).json({ error: 'API key not found' });
    }
    res.json({apiKey});
});

app.get("/nearby-cafes", async (req, res) => {
    const {lat, lng, radius} = req.query;
    const apiKey = process.env.GOOGLE_PLACES_API_KEY;
    if(!apiKey){
        return res.status(500).json({ error: 'API key not found' });
    }

    const url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=${radius}&type=cafe&key=${apiKey}`;
    try {
        const response = await axios.get(url);
        res.json(response.data);
    }catch(error){
        res.status(500).json({error: "Failed to fech date from GooglePlacesAPI"})
    }
});

app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});