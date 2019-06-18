pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                      // Account used to deploy contract
    bool private operational = true;                    // Blocks all state changes throughout the contract if false
    address[] multiCalls = new address[](0);            // Multisig
    uint256 constant multisig_threshold = 4;
    uint256 public constant MIN_AIRLINES_FUND = 10 ether;   // Airlines has to fund at least 10 ETH
    uint256 public constant MAX_FLIGHT_INSURANCE = 1 ether;

    // Define enum 'State' with the following values:
    enum State { 
    Registered, // 0
    Funded    // 1
    }

    // Struct of registered airline addresses
    struct RegisteredAirlines {
        bool isRegistered;
        bool isFunded;       // True is 10ETH has been payed.
        State airLineState;
    }
    mapping(address => RegisteredAirlines) registeredAirlines;   // Mapping for storing Registered Airlines

    event Registered(address _airLine);
    event Funded(address _airLine);
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
        registeredAirlines[airlineAddress] = RegisteredAirlines({
                                                isRegistered: true,
                                                isFunded: false,
                                                airLineState: State.Registered
                                            });
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
        require(msg.value >= minimumFund); 
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Prototyped
    modifier registered(address _airLine) {
        require(registeredAirlines[_airLine].airLineState == State.Registered);
        _;
    }
    
    // Define a modifier that checks if an item.state of a upc is Prototyped
    modifier funded(address _airLine) {
        require(registeredAirlines[_airLine].airLineState == State.Funded);
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
                                address account
                            )
                            external
                            requireIsOperational
    {
        require(mode != operational, "New mode must be different from existing mode");
        require(!registeredAirlines[account].isRegistered, "User is already registered.");

        bool isDuplicate = false;
        bool success = false;
        uint256 M = registeredAirlines.length.div(2);

        //If there are les than threshold (for this project the requirement is 4) airlines, do not use multisig and register it.
        if (registeredAirlines.length < multisig_threshold) {
            registeredAirlines[account] = RegisteredAirlines({
                                                isRegistered: true,
                                                isFunded: false,
                                                airLineState: State.Registered
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
            if (multiCalls.length >= M) {
                registeredAirlines[account] = RegisteredAirlines({
                                                    isRegistered: true,
                                                    isFunded: false,
                                                    airLineState: State.Registered
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
                                requireIsOperational
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
                            requireIsOperational
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
                                address insurance  
                            )
                            public
                            requireIsOperational
                            paidEnough
                            payable
    {
      insurance.transfer(msg.value);
      // emit the appropriate event
      emit Funded(_upc);
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        requireIsOperational
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
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

