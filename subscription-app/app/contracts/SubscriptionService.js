import web3 from '../utils/web3';
import SubscriptionService from './SubscriptionService.json';
const instance = new web3.eth.Contract(
  SubscriptionService.abi,
  '0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8'
);

export default instance;