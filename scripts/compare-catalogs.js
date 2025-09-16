#!/usr/bin/env node

import { createAdminApiClient } from "@shopify/admin-api-client";
import { config } from "dotenv";
import { writeFileSync } from "fs";
import { join } from "path";
import chalk from "chalk";
import cliProgress from "cli-progress";
import csvWriter from "csv-writer";

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

const PRODUCTS_QUERY = `
  query getProducts($first: Int!, $after: String) {
    products(first: $first, after: $after) {
      edges {
        node {
          id
          title
          handle
          status
          createdAt
          updatedAt
          resourcePublications(first: 20) {
            edges {
              node {
                publication {
                  name
                  id
                }
                publishDate
                isPublished
              }
            }
          }
        }
        cursor
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

const PUBLICATIONS_QUERY = `
  query getPublications($first: Int!) {
    publications(first: $first) {
      edges {
        node {
          id
          name
          supportsFuturePublishing
        }
      }
    }
  }
`;

async function getAllPublications(client) {
  console.log(chalk.blue("📡 Fetching sales channels..."));

  try {
    const response = await client.request(PUBLICATIONS_QUERY, {
      variables: { first: 50 },
    });

    const publications = response.data.publications.edges.map(
      (edge) => edge.node,
    );

    console.log(chalk.green(`✅ Found ${publications.length} sales channels:`));
    publications.forEach((pub) => {
      console.log(`  - ${pub.name} (${pub.id})`);
    });

    return publications;
  } catch (error) {
    console.error(chalk.red("❌ Failed to fetch publications:"), error.message);
    throw error;
  }
}

async function getAllProducts(client, progressBar) {
  const products = [];
  let hasNextPage = true;
  let cursor = null;
  const batchSize = 50;

  while (hasNextPage) {
    try {
      await new Promise((resolve) => setTimeout(resolve, 250));

      const response = await client.request(PRODUCTS_QUERY, {
        variables: {
          first: batchSize,
          after: cursor,
        },
      });

      if (!response.data || !response.data.products) {
        throw new Error('Unexpected API response structure');
      }

      const batch = response.data.products.edges.map((edge) => edge.node);
      products.push(...batch);

      hasNextPage = response.data.products.pageInfo.hasNextPage;
      cursor = response.data.products.pageInfo.endCursor;

      progressBar.increment(batch.length);
    } catch (error) {
      if (error.message.includes("rate limit") || error.message.includes("429")) {
        console.log(chalk.yellow("\n⏱️  Rate limit hit, waiting 5 seconds..."));
        await new Promise((resolve) => setTimeout(resolve, 5000));
        continue;
      }
      throw error;
    }
  }

  return products;
}

function analyzeProductCatalog(products, publications) {
  console.log(chalk.blue("\n🔍 Analyzing product catalog..."));

  const onlineStore = publications.find((pub) =>
    pub.name.toLowerCase().includes("online store"),
  );
  const hydrogenStore = publications.find((pub) =>
    !pub.name.toLowerCase().includes("online store") &&
    (pub.name.toLowerCase().includes("hydrogen") ||
      pub.name.toLowerCase().includes("storefront") ||
      pub.name.toLowerCase().includes("headless")),
  );

  if (!onlineStore) {
    console.warn(
      chalk.yellow("⚠️  Could not find 'Online Store' publication"),
    );
  }
  if (!hydrogenStore) {
    console.warn(
      chalk.yellow(
        "⚠️  Could not find Hydrogen/Headless storefront publication",
      ),
    );
  }

  const analysis = {
    onlineStoreOnly: [],
    hydrogenOnly: [],
    bothChannels: [],
    neitherChannel: [],
    totalProducts: products.length,
    onlineStoreId: onlineStore?.id,
    hydrogenStoreId: hydrogenStore?.id,
    onlineStoreName: onlineStore?.name || "Online Store (not found)",
    hydrogenStoreName: hydrogenStore?.name || "Hydrogen Store (not found)",
  };

  products.forEach((product) => {
    const publishedChannels = product.resourcePublications.edges
      .filter((edge) => edge.node.isPublished)
      .map((edge) => edge.node.publication.id);

    const isOnOnlineStore = onlineStore
      ? publishedChannels.includes(onlineStore.id)
      : false;
    const isOnHydrogen = hydrogenStore
      ? publishedChannels.includes(hydrogenStore.id)
      : false;

    const productInfo = {
      id: product.id.replace("gid://shopify/Product/", ""),
      title: product.title,
      handle: product.handle,
      status: product.status,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      publishedChannels: product.resourcePublications.edges
        .filter((edge) => edge.node.isPublished)
        .map((edge) => edge.node.publication.name),
    };

    if (isOnOnlineStore && isOnHydrogen) {
      analysis.bothChannels.push(productInfo);
    } else if (isOnOnlineStore && !isOnHydrogen) {
      analysis.onlineStoreOnly.push(productInfo);
    } else if (!isOnOnlineStore && isOnHydrogen) {
      analysis.hydrogenOnly.push(productInfo);
    } else {
      analysis.neitherChannel.push(productInfo);
    }
  });

  return analysis;
}

function printAnalysisSummary(analysis) {
  console.log(chalk.bold("\n📊 CATALOG COMPARISON SUMMARY"));
  console.log("=".repeat(50));

  console.log(chalk.blue(`\n🏪 ${analysis.onlineStoreName}`));
  console.log(chalk.blue(`⚡ ${analysis.hydrogenStoreName}`));

  console.log(chalk.bold(`\n📈 STATISTICS:`));
  console.log(`Total Products: ${chalk.cyan(analysis.totalProducts)}`);
  console.log(
    `Both Channels: ${chalk.green(analysis.bothChannels.length)} (${(
      (analysis.bothChannels.length / analysis.totalProducts) *
      100
    ).toFixed(1)}%)`,
  );
  console.log(
    `${analysis.onlineStoreName} Only: ${chalk.yellow(
      analysis.onlineStoreOnly.length,
    )} (${(
      (analysis.onlineStoreOnly.length / analysis.totalProducts) *
      100
    ).toFixed(1)}%)`,
  );
  console.log(
    `${analysis.hydrogenStoreName} Only: ${chalk.magenta(
      analysis.hydrogenOnly.length,
    )} (${(
      (analysis.hydrogenOnly.length / analysis.totalProducts) *
      100
    ).toFixed(1)}%)`,
  );
  console.log(
    `Neither Channel: ${chalk.red(analysis.neitherChannel.length)} (${(
      (analysis.neitherChannel.length / analysis.totalProducts) *
      100
    ).toFixed(1)}%)`,
  );

  if (analysis.onlineStoreOnly.length > 0) {
    console.log(
      chalk.yellow(`\n🔍 Products only in ${analysis.onlineStoreName}:`),
    );
    analysis.onlineStoreOnly.slice(0, 10).forEach((product) => {
      console.log(`  - ${product.title} (${product.handle})`);
    });
    if (analysis.onlineStoreOnly.length > 10) {
      console.log(
        chalk.gray(
          `    ... and ${analysis.onlineStoreOnly.length - 10} more`,
        ),
      );
    }
  }

  if (analysis.hydrogenOnly.length > 0) {
    console.log(
      chalk.magenta(`\n⚡ Products only in ${analysis.hydrogenStoreName}:`),
    );
    analysis.hydrogenOnly.slice(0, 10).forEach((product) => {
      console.log(`  - ${product.title} (${product.handle})`);
    });
    if (analysis.hydrogenOnly.length > 10) {
      console.log(
        chalk.gray(`    ... and ${analysis.hydrogenOnly.length - 10} more`),
      );
    }
  }

  if (analysis.neitherChannel.length > 0) {
    console.log(chalk.red("\n❌ Products not published to either channel:"));
    analysis.neitherChannel.slice(0, 5).forEach((product) => {
      console.log(`  - ${product.title} (${product.handle})`);
    });
    if (analysis.neitherChannel.length > 5) {
      console.log(
        chalk.gray(`    ... and ${analysis.neitherChannel.length - 5} more`),
      );
    }
  }
}

async function exportToCsv(analysis) {
  const timestamp = new Date().toISOString().slice(0, 19).replace(/:/g, "-");
  const csvPath = join(process.cwd(), `catalog-diff-${timestamp}.csv`);

  const allProducts = [
    ...analysis.bothChannels.map((p) => ({ ...p, availability: "Both" })),
    ...analysis.onlineStoreOnly.map((p) => ({
      ...p,
      availability: analysis.onlineStoreName,
    })),
    ...analysis.hydrogenOnly.map((p) => ({
      ...p,
      availability: analysis.hydrogenStoreName,
    })),
    ...analysis.neitherChannel.map((p) => ({ ...p, availability: "Neither" })),
  ];

  const csvWriterInstance = csvWriter.createObjectCsvWriter({
    path: csvPath,
    header: [
      { id: "id", title: "Product ID" },
      { id: "title", title: "Title" },
      { id: "handle", title: "Handle" },
      { id: "status", title: "Status" },
      { id: "availability", title: "Channel Availability" },
      { id: "publishedChannels", title: "Published Channels" },
      { id: "createdAt", title: "Created At" },
      { id: "updatedAt", title: "Updated At" },
    ],
  });

  await csvWriterInstance.writeRecords(
    allProducts.map((product) => ({
      ...product,
      publishedChannels: product.publishedChannels.join("; "),
    })),
  );

  console.log(chalk.green(`\n💾 Full report exported to: ${csvPath}`));
  return csvPath;
}

async function main() {
  console.log(
    chalk.bold.blue("🛍️  Shopify Catalog Comparison Tool\n"),
  );

  try {
    validateEnvironment();

    const client = createShopifyClient();

    const publications = await getAllPublications(client);

    console.log(chalk.blue("\n📦 Fetching products..."));
    const progressBar = new cliProgress.SingleBar(
      {
        format:
          "Progress |{bar}| {percentage}% | {value}/{total} products | ETA: {eta}s",
        barCompleteChar: "\u2588",
        barIncompleteChar: "\u2591",
      },
      cliProgress.Presets.shades_classic,
    );

    progressBar.start(1000, 0);

    const products = await getAllProducts(client, progressBar);
    progressBar.setTotal(products.length);
    progressBar.stop();

    console.log(chalk.green(`✅ Fetched ${products.length} products`));

    const analysis = analyzeProductCatalog(products, publications);

    printAnalysisSummary(analysis);

    await exportToCsv(analysis);

    console.log(chalk.green("\n✅ Catalog comparison complete!"));
  } catch (error) {
    console.error(chalk.red("❌ Error:"), error.message);
    if (error.stack) {
      console.error(chalk.gray(error.stack));
    }
    process.exit(1);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}