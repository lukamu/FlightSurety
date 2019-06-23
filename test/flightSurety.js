
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  const STATUS_CODE_LATE_AIRLINE = 20;

  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirLineRegistred.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) can be registered, but does not participate without funding', async () => {
    
    // ARRANGE
    let newAirline = accounts[3]; 

    // ACT
    await config.flightSuretyData.fund({from: config.firstAirline, value: web3.toWei("10", "ether")}); 
    await config.flightSuretyData.registerAirline(newAirline, {from: config.firstAirline});
    let result = await config.flightSuretyData.isAirLineRegistred.call(newAirline); 

    // ASSERT
    assert.equal(result, true, "Airline should be able to register another airline if it has provided funding");

  });

  it('(airline) can register a Flight using registerFlight()', async () => {
      
    // ARRANGE
    let timeStamp = Date.now();    
    let flightName = web3.fromAscii("UA3716");
  
    // ACT
    try {
        await config.flightSuretyApp.registerFlight(flightName, timeStamp, config.firstAirline, {from: config.firstAirline});
    }
    catch(e) {
        console.log(e);
    }

    let result = await config.flightSuretyApp.isFlightRegistered.call(flightName); 

    // ASSERT
    assert.equal(result, true, "The flight is not registered");
  });

  it('(passenger) can buy insurance using buy()', async () => {
    // ARRANGE
    let passenger = accounts[4];
    let flightName = web3.fromAscii("UA3716");
    let price = web3.toWei("1", 'ether')
    
    // ACT
    await config.flightSuretyApp.buy(flightName,{from: passenger, value: price});

    let result  = await config.flightSuretyApp.getFlightInsuranceAmount(flightName, {from: passenger});
    result = result.toString()

    // ASSERT
    assert.equal(price, result, "Insurance bought unsuccessfully"); 
});

it('(multiparty) Registration of more than 4 airlines requires multiseg', async () => {
    
    // ARRANGE
    let newAirline1 = accounts[5];
    let newAirline2 = accounts[6];
    let newAirline3 = accounts[7];
    let newAirline4 = accounts[8];

    // ACT
    // firstAirline registers the first 3 new airlines
    await config.flightSuretyData.registerAirline(newAirline1, {from: config.firstAirline});
    await config.flightSuretyData.fund({from: newAirline1, value: web3.toWei("10", "ether")});
    await config.flightSuretyData.registerAirline(newAirline2, {from: config.firstAirline});
    await config.flightSuretyData.fund({from: newAirline2, value: web3.toWei("10", "ether")});
    await config.flightSuretyData.registerAirline(newAirline3, {from: config.firstAirline});
    await config.flightSuretyData.fund({from: newAirline3, value: web3.toWei("10", "ether")});
 
    // The first 3 airlines should be registred.
    let result1 = await config.flightSuretyData.isAirLineRegistred.call(newAirline1); 
    let result2 = await config.flightSuretyData.isAirLineRegistred.call(newAirline2);
    let result3 = await config.flightSuretyData.isAirLineRegistred.call(newAirline3); 

    // firstAirlines votes to register the 4th airlines
    await config.flightSuretyData.registerAirline(newAirline4, {from: config.firstAirline});
    // Multiseg enabled: The 4th airline shouldn't be registred because 1 more vote is missing.
    let result4 = await config.flightSuretyData.isAirLineRegistred.call(newAirline4);

    // 3 more airlines vote to register airline4
    await config.flightSuretyData.registerAirline(newAirline4, {from: newAirline1});
    let result5 = await config.flightSuretyData.isAirLineRegistred.call(newAirline4);

    // ASSERT
    assert.equal(result1, true, "Airline 1 should be registered");
    assert.equal(result2, true, "Airline 2 should be registered");
    assert.equal(result3, true, "Airline 3 should be registered");    
    assert.equal(result4, false, "Airline 4 should not be registered: 1 vote out of 2, and 4 airlines must be registred.)");
    assert.equal(result5, true, "Airline 4 should now be registered");
  });
});
