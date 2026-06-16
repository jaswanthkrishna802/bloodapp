const ExcelJS = require('exceljs');
const path = require('path');

async function createExcelReport(testResults, filename = 'report_web.xlsx') {
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Test Results');

    worksheet.columns = [
        { header: 'Test ID', key: 'id', width: 10 },
        { header: 'Category', key: 'category', width: 20 },
        { header: 'Test Case Name', key: 'name', width: 40 },
        { header: 'Status', key: 'status', width: 15 },
        { header: 'Error/Details', key: 'details', width: 50 },
        { header: 'Timestamp', key: 'timestamp', width: 25 }
    ];

    testResults.forEach(result => {
        const row = worksheet.addRow(result);
        const statusCell = row.getCell('status');
        if (result.status === 'Pass') {
            statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF90EE90' } };
        } else {
            statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFCCCB' } };
        }
    });

    const filePath = path.join(__dirname, '..', filename);
    await workbook.xlsx.writeFile(filePath);
    console.log(`Web Report generated: ${filePath}`);
}

module.exports = { createExcelReport };
