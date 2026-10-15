const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();
const now = Timestamp.now();

const img = (seed) => `https://picsum.photos/seed/${seed}/800/600`;

const properties = [
  {
    id: 'seed-apt-1',
    status: 'published',
    title: 'Appartement S+2 Les Berges du Lac',
    description: 'Bel appartement lumineux au 3ème étage, proche de toutes commodités.',
    price: 450000,
    currency: 'TND',
    transactionType: 'buy',
    propertyType: 'apartment',
    governorate: 'Tunis',
    city: 'Les Berges du Lac',
    bedrooms: 2,
    bathrooms: 2,
    surface: 110,
    amenities: ['parking', 'elevator'],
    imageUrls: [img('immo-apt-1a'), img('immo-apt-1b')],
    verificationStatus: 'verified',
    ownerId: 'seed',
    ownerName: 'Ahmed Ben Ali',
    ownerRole: 'owner',
    views: 0,
    favoritesCount: 0,
  },
  {
    id: 'seed-apt-2',
    status: 'published',
    title: 'Appartement S+3 Lac 2',
    description: 'Spacieux S+3 avec balcon, résidence sécurisée.',
    price: 620000,
    currency: 'TND',
    transactionType: 'buy',
    propertyType: 'apartment',
    governorate: 'Tunis',
    city: 'Les Berges du Lac',
    bedrooms: 3,
    bathrooms: 2,
    surface: 140,
    amenities: ['parking', 'balcony', 'security'],
    imageUrls: [img('immo-apt-2a')],
    verificationStatus: 'pending',
    ownerId: 'seed',
    ownerName: 'Agence Lac Immobilier',
    ownerRole: 'agency',
    views: 0,
    favoritesCount: 0,
  },
  {
    id: 'seed-villa-1',
    status: 'published',
    title: 'Villa avec piscine à Hammamet',
    description: 'Villa contemporaine avec jardin et piscine, à 5 minutes de la plage.',
    price: 1250000,
    currency: 'TND',
    transactionType: 'buy',
    propertyType: 'villa',
    governorate: 'Nabeul',
    city: 'Hammamet',
    bedrooms: 4,
    bathrooms: 3,
    surface: 320,
    amenities: ['pool', 'garden', 'seaView', 'parking'],
    imageUrls: [img('immo-villa-1a'), img('immo-villa-1b'), img('immo-villa-1c')],
    verificationStatus: 'verified',
    ownerId: 'seed',
    ownerName: 'Sami Trabelsi',
    ownerRole: 'agent',
    views: 0,
    favoritesCount: 0,
  },
];

async function main() {
  for (const { id, ...data } of properties) {
    await db.collection('properties').doc(id).set({
      ...data,
      createdAt: now,
      updatedAt: now,
    });
    console.log('OK', id);
  }
  console.log('Done.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});