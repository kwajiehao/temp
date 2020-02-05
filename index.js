'use strict';
const express = require('express')
const cors = require('cors')
const bodyParser = require('body-parser')

// Instantiate express server
const app = express()
app.use(cors())
app.use(bodyParser.json())

// define GET endpoint for start-server-and-test library to work
app.get('/', async (req, res) => res.send('Hello World'))