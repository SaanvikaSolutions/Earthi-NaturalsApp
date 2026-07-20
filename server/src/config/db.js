import mongoose from 'mongoose';

/**
 * Connect to MongoDB Atlas using the MONGO_URI env var.
 * The connection string (and its credentials) live only in `.env`,
 * never in source control.
 */
export async function connectDB() {
  const uri = process.env.MONGO_URI;
  if (!uri) {
    throw new Error('MONGO_URI is not set. Copy server/.env.example to server/.env and fill it in.');
  }

  mongoose.set('strictQuery', true);

  await mongoose.connect(uri, {
    dbName: process.env.DB_NAME || 'test',
    serverSelectionTimeoutMS: 10000,
  });

  const { host, name } = mongoose.connection;
  console.log(`✅ MongoDB connected: ${host}/${name}`);
}
