import { getFullnodeUrl, SuiClient} from "@mysten/sui/client";
import { SuiGraphQLClient } from "@mysten/sui/graphql";
import { createNetworkConfig } from "@mysten/dapp-kit";

const { networkConfig, useNetworkVariable, useNetworkVariables } =
  createNetworkConfig({
    testnet: {
      url: getFullnodeUrl("testnet"),
      packageID: "0x3cba1f04cd295907b4870d703e7a715bdb426b15e7e4925e9edfec06ab51ce62",
      state:"0x6ee75f9e8cbfd410b662c69c6131d38c02397b8365810a018fc5ebab91ed6e1d"
    },
  });

const suiClient = new SuiClient({
  url: networkConfig.testnet.url,
});

const suiGraphQLClient = new SuiGraphQLClient({
  url: `https://sui-testnet.mystenlabs.com/graphql`,
});

export { useNetworkVariable, useNetworkVariables, networkConfig, suiClient, suiGraphQLClient };
