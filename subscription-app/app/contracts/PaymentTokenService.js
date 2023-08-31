import web3 from '../utils/web3';
import PaymentTokenService from './PaymentToken.json'; // O arquivo JSON do contrato compilado

const instance = new web3.eth.Contract(
    PaymentTokenService.abi,
  '0xd9145CCE52D386f254917e481eB44e9943F39138' // Substitua pelo endereço real do contrato
);

export default instance;