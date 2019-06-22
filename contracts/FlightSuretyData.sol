pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                          // Account used to deploy contract
    bool private operational = true;                        // Blocks all state changes throughout the contract if false
    
    uint256 public constant MIN_AIRLINES_FUND = 10 ether;   // Airlines has to fund at least 10 ETH
    uint8 private constant MULTISIG_THRESHOLD = 4;          // Minimum number of airlines required to enable multisig 
                                                            // for registering new airlines.

    uint256 public total_funded_balance = 0;                // Funded from all airlines
    address[] multiCalls = new address[](0);                // Multisig

    // Struct of registered airline addresses
    struct Airline {
        bool isRegistered;
        bool isFunded;       
    }
    mapping(address => Airline) airline;    // Mapping for storing Airlines
    uint256 totalFundedAirLines;               // Unfortunatly Solidity doesn't have the iterator for a structure, so I have to
                                            // the total number of funded airline to manage how many airlines can vote.

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                    address airlineAddress
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        // Register the first airline
        airline[airlineAddress] = Airline({
                                                isRegistered: true,
                                                isFunded: false
                                            });
        totalFundedAirLines = 0;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    // Define a modifier that checks if the paid amount is sufficient to cover the minimu fund requested.
    modifier paidEnough() { 
        require(msg.value >= MIN_AIRLINES_FUND, 'Minimum fund required is 10 ETH'); 
        _;
    }

    // Define a modifier that checks if an airline is registred.
    modifier requireRegistered(address _airLine) {
        require(airline[_airLine].isRegistered == true, 'Caller is not registered, and can not register another airline');
        _;
    }

    // Define a modifier that checks if an airline is registred.
    modifier requireIsNotRegistered(address _airLine) {
        require(airline[_airLine].isRegistered == false, 'AirLine is already registered');
        _;
    }
    
    // Define a modifier that checks if an airline is funded.
    modifier requireFunded(address _airLine) {
        require(airline[_airLine].isFunded == true, 'AirLine his not funded');
        _;
    }

    // Define a modifier that checks if airline has been already funded
    modifier requireIsNotAlreadyFunded (address account)
    {
        require(airline[account].isFunded == false, "Airline has been already funded");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    /**
    * @dev Returns if an airlines is funded or not.
    *
    * @return A boolean: true is is funded, false otherwise.
    */ 
    function isAirLineFunded(address _airline) view public returns(bool) {
        return airline[_airline].isFunded;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (
                                address airline_address
                            )
                            external
                            requireIsOperational
                            requireRegistered(msg.sender)
                            requireFunded(msg.sender)
                            requireIsNotRegistered(airline_address)
                            returns(bool success, uint256 signed)
    {
        bool isDuplicate = false;
        success = false;

        //If there are less than MULTISIG_THRESHOLD registered airlines, do not use multisig and register it.
        if (totalFundedAirLines < MULTISIG_THRESHOLD) {
            airline[airline_address] = Airline({
                                                isRegistered: true,
                                                isFunded: false
                                            });
            success = true;
        } else {
            for(uint c=0; c<multiCalls.length; c++) {
                if (multiCalls[c] == msg.sender) {
                    isDuplicate = true;
                    break;
                }
            }
            require(!isDuplicate, "Caller has already called this function.");

            multiCalls.push(msg.sender);
            if (multiCalls.length >= totalFundedAirLines.div(2)) {
                airline[airline_address] = Airline({
                                                    isRegistered: true,
                                                    isFunded: false
                                                });
                success = true;
                multiCalls = new address[](0);      
            }
        }
        return (success, multiCalls.length);
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            requireIsOperational
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (
                            )
                            public
                            requireIsOperational
                            requireRegistered(msg.sender)
                            requireIsNotAlreadyFunded(msg.sender)
                            paidEnough
                            payable
    {
      airline[msg.sender].isFunded = true;  
      total_funded_balance.add(msg.value);
      totalFundedAirLines = totalFundedAirLines.add(1);
      contractOwner.transfer(msg.value);
    }

    function getFlightKey
                        (
                            address _airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        internal
                        requireIsOperational
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(_airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

