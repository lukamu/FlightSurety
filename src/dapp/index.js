
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })

        // Fund Airline
        // User-submitted transaction
        DOM.elid('fund').addEventListener('click', () => {
            contract.fund((error, result) => {
                console.log(result);
            });
        })  
        
        // Register Flight
        // User-submitted transaction
        DOM.elid('registerFlight').addEventListener('click', () => {
            let flight = DOM.elid('select_register_flight').value;
            contract.registerFlight(flight,(error, data) => {
                console.log(data);
            });
        })

        // Is a Registered Flight
        // User-submitted transaction
        DOM.elid('isRegisteredFlight').addEventListener('click', () => {
            let flight = DOM.elid('select_register_flight').value;
            contract.isFlightRegistered(flight,(error, data) => {
                console.log(data);
            });
        })

        // Buy Insurance
        // User-submitted transaction
        DOM.elid('buyInsurance').addEventListener('click', () => {            
            let insuranceValue = DOM.elid('insuranceValue').value;
            let flight = DOM.elid('select_buy_insurance').value;            
            contract.buy(flight,insuranceValue,(error, result) => {
                console.log(result);
            });
        })

        // Fetch Status
        // User-submitted transaction
        DOM.elid('fetchFlightStatus').addEventListener('click', () => {
            let flight = DOM.elid('select_fetch').value;   
            contract.fetchFlightStatus(flight,(error, result) => {
                console.log(result);
            });
        }) 

        // Withdrawal
        // User-submitted transaction
        DOM.elid('withdraw').addEventListener('click', () => {
            contract.withdraw((error, data) => {
                console.log(data);
            });
        }) 
    
    });
    

})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







