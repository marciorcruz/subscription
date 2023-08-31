import Web3 from 'web3';

let web3;

if (typeof window !== 'undefined' && typeof window.ethereum !== 'undefined') {
  // Use the web3 provided by the browser
  web3 = new Web3(window.ethereum);
  window.ethereum.enable(); // Request account access
} else {
  // Fallback to a local Ethereum provider
  const provider = new Web3.providers.HttpProvider('https://rpc.sepolia.org');
  web3 = new Web3(provider);
}

export default web3;