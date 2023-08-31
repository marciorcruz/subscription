"use client";
import { useState } from "react";
import Image from 'next/image'
import SubscriptionService from '../app/contracts/SubscriptionService.json'; // Importe o contrato SubscriptionService
import PaymentTokenService from '../app/contracts/PaymentToken.json'; // Importe o contrato ERC-20
import { ethers } from "ethers";


export default function Home() {
  const [selectedDuration, setSelectedDuration] = useState(0);
  const handleDurationSelection = (duration: any) => {
    setSelectedDuration(duration);
  };
  const handleStartSubscription = async () => {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();

    // // Aprovar a transferência do token ERC-20 ao contrato SubscriptionService
    const subscriptionServiceContract = new ethers.Contract(
      "0xd3fa55cb81FDFEBf8c239F83598e1958B0995b7D", // Substitua pelo endereço do contrato SubscriptionService
      SubscriptionService.abi,
      signer
    );

    const tokenContract = new ethers.Contract(
      "0xc171A1D6280852Bd3Df5351AEE75A60FDb96fC85", // Substitua pelo endereço do contrato ERC-20
      PaymentTokenService.abi,
      signer
    );

    try {      // Obter a quantidade necessária de tokens para a duração selecionada
      const teste = await subscriptionServiceContract.initialPrice();
      const depositAmount = selectedDuration * 1000000000000000000;
      // Aprovar a transferência de tokens do usuário para o contrato SubscriptionService
      const transactionAproove = await tokenContract.approve("0xd3fa55cb81FDFEBf8c239F83598e1958B0995b7D", depositAmount.toString());
      await transactionAproove.wait();
      // Chamar a função startSubscription do contrato SubscriptionService
      const transaction = await subscriptionServiceContract.startSubscription(selectedDuration);
      // Aguarde a confirmação da transação
      await transaction.wait();
      console.log('Subscription started successfully', transaction.hash);
    } catch (error) {
      console.error('Error starting subscription:', error);
    }
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      {selectedDuration}
      <div className="flex space-x-4">
        <button onClick={() => handleDurationSelection(30)}>30 days</button>
        <button onClick={() => handleDurationSelection(90)}>90 days</button>
        <button onClick={() => handleDurationSelection(365)}>365 days</button>
      </div>
      <button onClick={handleStartSubscription}>Start Subscription</button>
    </main>
  )
}