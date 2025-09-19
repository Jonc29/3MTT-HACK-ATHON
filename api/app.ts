import express from 'express';
import { home } from './routes/home.ts';

const app = express();
const port = 3000;

app.get('/', home);

app.listen(port, () => console.log(`Server running on port ${port}`));

