#!/usr/bin/env node

import { createAdminApiClient } from "@shopify/admin-api-client";
import { config } from "dotenv";
import { readFileSync, readdirSync } from "fs";
import chalk from "chalk";
import cliProgress from "cli-progress";

config({ path: ".env.catalog" });

const REQUIRED_ENV_VARS = ["SHOPIFY_ADMIN_ACCESS_TOKEN", "SHOPIFY_STORE_URL"];

function validateEnvironment() {
  const missing = REQUIRED_ENV_VARS.filter(
    (varName) => !process.env[varName],
  );

  if (missing.length > 0) {
    console.error(
      chalk.red(
        `❌ Missing required environment variables: ${missing.join(", ")}`,
      ),
    );
    console.log(
      chalk.yellow(
        "💡 Please create a .env.catalog file with the required variables",
      ),
    );
    process.exit(1);
  }
}

function createShopifyClient() {
  return createAdminApiClient({
    storeDomain: process.env.SHOPIFY_STORE_URL.replace(/^https?:\/\//, ""),
    accessToken: process.env.SHOPIFY_ADMIN_ACCESS_TOKEN,
    apiVersion: "2024-10",
  });
}

const PUBLISH_MUTATION = `
  mutation publishablePublish($id: ID!, $input: [PublicationInput!]!) {
    publishablePublish(id: $id, input: $input) {
      publishable {
        availablePublicationsCount {
          count
        }
      }
      shop {
        publicationCount
      }
      userErrors {
        field
        message
      }
    }
  }
`;

const VERIFY_PUBLICATION_QUERY = `
  query getProductPublications($id: ID!) {
    product(id: $id) {
      id
      title
      resourcePublications(first: 20) {
        edges {
          node {
            publication {
              name
              id
            }
            isPublished
          }
        }
      }
    }
  }
`;

function findLatestCatalogDiff() {
  try {
    // Look for the most recent catalog diff file
    const files = readdirSync('.')
      .filter(file => file.startsWith('catalog-diff-') && file.endsWith('.csv'))
      .sort()
      .reverse();

    if (files.length === 0) {
      throw new Error('No catalog diff file found. Please run compare-catalogs.js first.');
    }

    return files[0];
  } catch (error) {
    console.error(chalk.red('❌ Error finding catalog diff file:'), error.message);
    process.exit(1);
  }
}

function parseOnlineStoreOnlyProducts() {
  const csvFile = findLatestCatalogDiff();
  console.log(chalk.blue(`📄 Reading from: ${csvFile}`));

  try {
    const csvContent = readFileSync(csvFile, 'utf-8');
    const lines = csvContent.split('\n');
    const products = [];

    // Skip header line
    for (let i = 1; i < lines.length; i++) {
      const line = lines[i].trim();
      if (!line) continue;

      const columns = line.split(',');
      if (columns.length >= 5 && columns[4] === 'Online Store') {
        products.push({
          id: `gid://shopify/Product/${columns[0]}`,
          shopifyId: columns[0],
          title: columns[1].replace(/^"/, '').replace(/"$/, ''), // Remove quotes if present
          handle: columns[2],
          status: columns[3]
        });
      }
    }

    return products;
  } catch (error) {
    console.error(chalk.red('❌ Error reading CSV file:'), error.message);
    process.exit(1);
  }
}

async function publishProductToHydrogen(client, product, hydrogenPublicationId, progressBar) {
  try {
    // Add delay to respect rate limits
    await new Promise(resolve => setTimeout(resolve, 300));

    const response = await client.request(PUBLISH_MUTATION, {
      variables: {
        id: product.id,
        input: [
          {
            publicationId: hydrogenPublicationId,
            publishDate: new Date().toISOString()
          }
        ]
      }
    });

    if (response.data?.publishablePublish?.userErrors?.length > 0) {
      const errors = response.data.publishablePublish.userErrors;
      throw new Error(`GraphQL errors: ${errors.map(e => e.message).join(', ')}`);
    }

    progressBar.increment();
    return { success: true, product };
  } catch (error) {
    if (error.message.includes('rate limit') || error.message.includes('429')) {
      // Wait longer for rate limits and retry
      console.log(chalk.yellow(`\n⏱️  Rate limit hit for ${product.title}, waiting 5 seconds...`));
      await new Promise(resolve => setTimeout(resolve, 5000));
      return await publishProductToHydrogen(client, product, hydrogenPublicationId, progressBar);
    }

    return { success: false, product, error: error.message };
  }
}

async function verifyPublications(client, products, hydrogenPublicationId) {
  console.log(chalk.blue('\n🔍 Verifying publications...'));

  const verified = [];
  const failed = [];

  for (const product of products.slice(0, 5)) { // Sample check first 5
    try {
      await new Promise(resolve => setTimeout(resolve, 200));

      const response = await client.request(VERIFY_PUBLICATION_QUERY, {
        variables: { id: product.id }
      });

      const isPublishedToHydrogen = response.data.product.resourcePublications.edges
        .some(edge =>
          edge.node.publication.id === hydrogenPublicationId &&
          edge.node.isPublished
        );

      if (isPublishedToHydrogen) {
        verified.push(product);
      } else {
        failed.push(product);
      }
    } catch (error) {
      console.log(chalk.yellow(`⚠️  Could not verify ${product.title}: ${error.message}`));
      failed.push(product);
    }
  }

  console.log(chalk.green(`✅ Verified: ${verified.length} products successfully published`));
  if (failed.length > 0) {
    console.log(chalk.red(`❌ Failed verification: ${failed.length} products`));
    failed.forEach(p => console.log(`  - ${p.title}`));
  }

  return { verified, failed };
}

async function main() {
  console.log(chalk.bold.blue("🚀 Publish Products to Hydrogen Storefront\n"));

  try {
    validateEnvironment();

    const client = createShopifyClient();

    // Parse products that need to be published
    const productsToPublish = parseOnlineStoreOnlyProducts();
    console.log(chalk.green(`📦 Found ${productsToPublish.length} products to publish to Hydrogen`));

    if (productsToPublish.length === 0) {
      console.log(chalk.yellow('🎉 No products need to be published - everything is already in sync!'));
      return;
    }

    // Get Hydrogen publication ID - Update this with your actual Hydrogen publication ID
    // Run the comparison script first to find your Hydrogen storefront publication ID
    const hydrogenPublicationId = 'gid://shopify/Publication/173130514688';
    console.log(chalk.blue(`🎯 Target: Hydrogen Bubble Goods (${hydrogenPublicationId})`));

    // Confirm before proceeding
    console.log(chalk.yellow(`\n⚠️  About to publish ${productsToPublish.length} products to Hydrogen storefront.`));
    console.log(chalk.yellow('This action cannot be easily undone.'));

    // For safety, let's show first few products
    console.log(chalk.gray('\nFirst few products to be published:'));
    productsToPublish.slice(0, 5).forEach(p => {
      console.log(chalk.gray(`  - ${p.title}`));
    });

    if (productsToPublish.length > 5) {
      console.log(chalk.gray(`  ... and ${productsToPublish.length - 5} more`));
    }

    console.log(chalk.blue('\n📤 Starting publication process...'));

    // Set up progress bar
    const progressBar = new cliProgress.SingleBar({
      format: 'Publishing |{bar}| {percentage}% | {value}/{total} products | ETA: {eta}s',
      barCompleteChar: '\u2588',
      barIncompleteChar: '\u2591',
    }, cliProgress.Presets.shades_classic);

    progressBar.start(productsToPublish.length, 0);

    // Publish products in batches
    const results = [];
    const batchSize = 10;

    for (let i = 0; i < productsToPublish.length; i += batchSize) {
      const batch = productsToPublish.slice(i, i + batchSize);
      const batchPromises = batch.map(product =>
        publishProductToHydrogen(client, product, hydrogenPublicationId, progressBar)
      );

      const batchResults = await Promise.all(batchPromises);
      results.push(...batchResults);

      // Brief pause between batches
      await new Promise(resolve => setTimeout(resolve, 1000));
    }

    progressBar.stop();

    // Analyze results
    const successful = results.filter(r => r.success);
    const failed = results.filter(r => !r.success);

    console.log(chalk.green(`\n✅ Successfully published: ${successful.length} products`));

    if (failed.length > 0) {
      console.log(chalk.red(`❌ Failed to publish: ${failed.length} products`));
      console.log(chalk.red('\nFailed products:'));
      failed.forEach(result => {
        console.log(chalk.red(`  - ${result.product.title}: ${result.error}`));
      });
    }

    // Verify a sample of publications
    if (successful.length > 0) {
      await verifyPublications(client, successful.slice(0, 5).map(r => r.product), hydrogenPublicationId);
    }

    console.log(chalk.green('\n🎉 Publication process complete!'));
    console.log(chalk.blue('💡 Run the catalog comparison script again to verify all products are now synchronized.'));

  } catch (error) {
    console.error(chalk.red('❌ Error:'), error.message);
    if (error.stack) {
      console.error(chalk.gray(error.stack));
    }
    process.exit(1);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}