using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using NUnit.Framework;

namespace ITI.PrimarySchool.DB.Tests
{
    [TestFixture]
    public class SimpleTests
    {
        [Test]
        public async Task DisplayTeacher()
        {
            using( SqlConnection conn = new SqlConnection( @"Server=.\SQLSERVER;Database=PrimarySchool;Trusted_Connection=True;" ) )
            {
                await conn.OpenAsync();
                List<Teacher> originalTeachers = await GetTeachers( conn );
                string firstName = CreateRandomName();
                string lastName = CreateRandomName();
                int teacherId = await CreateTeacher( firstName, lastName, conn );
                List<Teacher> teachers = await GetTeachers( conn );

                IEnumerable<Teacher> intersection = teachers.Intersect( originalTeachers );
                Assert.That( intersection, Is.EquivalentTo( originalTeachers ) );
                CollectionAssert.Contains( teachers, new Teacher { FirstName = firstName, LastName = lastName } );

                await RemoveTeacher( teacherId, conn );
            }
        }

        async Task RemoveTeacher( int teacherId, SqlConnection conn )
        {
            string cmdText = "delete from ps.tTeacher where TeacherId = @TeacherId;";
            using( SqlCommand command = new SqlCommand( cmdText, conn ) )
            {
                command.Parameters.AddWithValue( "@TeacherId", teacherId );
                await command.ExecuteNonQueryAsync();
            }
        }

        async Task<int> CreateTeacher( string firstName, string lastName, SqlConnection conn )
        {
            string cmdText = "insert into ps.tTeacher(FirstName, LastName) values(@FirstName, @LastName);";
            using( SqlCommand command = new SqlCommand( cmdText, conn ) )
            {
                command.Parameters.AddWithValue( "@FirstName", firstName );
                command.Parameters.AddWithValue( "@LastName", lastName );
                await command.ExecuteNonQueryAsync();
            }

            cmdText = "select t.TeacherId from ps.tTeacher t where t.FirstName = @FirstName and t.LastName = @LastName;";
            using( SqlCommand command = new SqlCommand( cmdText, conn ) )
            {
                command.Parameters.AddWithValue( "@FirstName", firstName );
                command.Parameters.AddWithValue( "@LastName", lastName );
                return ( int )await command.ExecuteScalarAsync();
            }
        }

        string CreateRandomName() => string.Format( "Test-{0}", Guid.NewGuid().ToString().Substring( 0, 8 ) );

        async Task<List<Teacher>> GetTeachers( SqlConnection conn )
        {
            using( SqlCommand command = new SqlCommand( "select t.FirstName, t.LastName from ps.tTeacher t where t.TeacherId <> 0;", conn ) )
            {
                using( SqlDataReader reader = await command.ExecuteReaderAsync() )
                {
                    List<Teacher> teachers = new List<Teacher>();
                    while( await reader.ReadAsync() )
                    {
                        teachers.Add( new Teacher
                        {
                            FirstName = ( string )reader[ "FirstName" ],
                            LastName = ( string )reader[ "LastName" ]
                        } );
                    }

                    return teachers;
                }
            }
        }

        public class Teacher
        {
            public string FirstName { get; set; }

            public string LastName { get; set; }

            public override bool Equals( object obj )
            {
                Teacher other = obj as Teacher;
                return other != null && other.FirstName == FirstName && other.LastName == LastName;
            }

            public override int GetHashCode()
            {
                return FirstName.GetHashCode() + LastName.GetHashCode();
            }
        }
    }
}
