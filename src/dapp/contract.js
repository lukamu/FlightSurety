import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';

import Config from './config.json';
import Web3 from 'web3';

var first_airline;

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
        first_airline = config.appAddress;
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

    fund(callback) {
        let self = this;
        self.flightSuretyApp.methods
        .fund(self.airlines[0])
        .send({from:first_airline,value: web3.toWei("10", "ether")}, callback);
     }

    registerFlight(flight, callback) {
        let self = this;
        let time = Number(Math.floor(Date.now() / 1000));
        self.flightSuretyApp.methods     
        .registerFlight(this.web3.utils.fromAscii(flight),time,first_airline).send({ from: first_airline}, callback);    
     }

    isFlightRegistered(flight,callback) {
        let self = this;
        self.flightSuretyApp.methods.isFlightRegistered(this.web3.utils.fromAscii(flight)).call({ from: first_airline}, callback);
     }

     buy(flight,insuranceValue,callback) {
        let self = this;
        const amount = insuranceValue;
        const amountToSend = this.web3.utils.toWei(amount.toString(), "ether");
        self.flightSuretyApp.methods.buy(this.web3.utils.fromAscii(flight))
        .send({ from: self.owner, value: amountToSend, gas: 1000000}, callback);
     }

     withdaw(callback) {
        let self = this;
        self.flightSuretyApp.methods        
        .withdraw()
        .send({ from: self.owner}, callback);
     }     
}